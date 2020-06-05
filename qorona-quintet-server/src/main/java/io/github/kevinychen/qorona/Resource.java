package io.github.kevinychen.qorona;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.UUID;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.io.Files;

public class Resource implements Service {

    private static final Logger LOGGER = LoggerFactory.getLogger(Resource.class);

    private volatile Config currConfig = new Config();
    private volatile boolean done;
    private volatile Consensus consensus;
    private Map<UUID, Instant> latestHeartbeats = new HashMap<>();

    @Override
    public synchronized void setConfig(Config config) {
        LOGGER.info("Updating config: {}", config);
        currConfig = config;
        latestHeartbeats.clear();
        done = false;
    }

    @Override
    public synchronized void setDone() {
        done = true;
    }

    @Override
    public synchronized ReadyResponse ready() {
        Instant now = Instant.now();

        for (UUID client : new HashSet<>(latestHeartbeats.keySet()))
            if (latestHeartbeats.get(client).isBefore(now.minus(15, ChronoUnit.SECONDS)))
                latestHeartbeats.remove(client);

        UUID client = UUID.randomUUID();
        boolean isMaster = latestHeartbeats.isEmpty();
        latestHeartbeats.put(client, now);

        LOGGER.info("Clients: {}", latestHeartbeats);
        if (latestHeartbeats.size() >= currConfig.numClients)
            consensus = new Consensus(UUID.randomUUID(), latestHeartbeats.keySet(), now.plus(5, ChronoUnit.SECONDS).toEpochMilli());
        else
            consensus = null;

        return new ReadyResponse(currConfig.musescoreUrl, client, isMaster);
    }

    @Override
    public synchronized Consensus pingConsensus(UUID client) {
        latestHeartbeats.put(client, Instant.now());
        return consensus;
    }

    @Override
    public synchronized DoneResponse pingDone() {
        return new DoneResponse(done);
    }

    @Override
    public synchronized void uploadAudio(UUID recordingId, UUID client, InputStream audio) throws Exception {
        upload(recordingId, client, audio, ".m4a");
    }

    private void upload(UUID recordingId, UUID client, InputStream data, String extension) throws Exception {
        File newFile = Paths.get("data", recordingId.toString(), client + extension).toFile();
        FileUtils.copyInputStreamToFile(data, newFile);

        File tempFile = new File(newFile.getParentFile(), "temp.m4a");
        File destFile = new File(newFile.getParentFile(), "merged.m4a");
        tempFile.delete();
        destFile.delete();

        File[] files = newFile.getParentFile().listFiles();
        for (File file : files)
            if (file.getName().endsWith(".m4a"))
                if (!destFile.exists()) {
                    Files.copy(file, destFile);
                } else {
                    Files.copy(destFile, tempFile);
                    int status = Runtime.getRuntime().exec(new String[] {
                            "/bin/sh",
                            "-c",
                            // https://stackoverflow.com/questions/14498539/how-to-overlay-downmix-two-audio-files-using-ffmpeg
                            String.format("yes | /usr/local/bin/ffmpeg -i %s -i %s -filter_complex amerge=inputs=2 -ac 2 %s",
                                tempFile.getAbsolutePath(), file.getAbsolutePath(), destFile.getAbsolutePath()),
                    }).waitFor();
                    System.out.println(status);
                }

        File outputFile = Paths.get("src", "main", "resources", "public", "recordings", recordingId + ".mp4").toFile();
        for (File file : files)
            if (file.getName().endsWith(".mp4")) {
                Runtime.getRuntime().exec(new String[] {
                        "/bin/sh",
                        "-c",
                        // https://video.stackexchange.com/questions/11898/merge-mp4-with-m4a
                        String.format("yes | /usr/local/bin/ffmpeg -i %s -i %s -c:v copy -map 0:v:0 -map 1:a:0 %s",
                            destFile.getAbsolutePath(), file.getAbsolutePath(), outputFile.getAbsolutePath()),
                }).waitFor();
            }
    }
}
