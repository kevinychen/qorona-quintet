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

import javax.ws.rs.core.Response;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.io.Files;

public class Resource implements Service {

    private static final Logger LOGGER = LoggerFactory.getLogger(Resource.class);

    private volatile Config currConfig = new Config();
    private volatile UUID recordingId = UUID.randomUUID();
    private volatile boolean done;
    private volatile Consensus consensus;
    private Map<String, Instant> latestHeartbeats = new HashMap<>();

    @Override
    public synchronized void setConfig(Config config) {
        LOGGER.info("Updating config: {}", config);
        currConfig = config;
        recordingId = UUID.randomUUID();
        done = false;
        latestHeartbeats.clear();
    }

    @Override
    public synchronized void setDone() {
        done = true;
    }

    @Override
    public synchronized ReadyResponse ready() {
        Instant now = Instant.now();

        for (String clientId : new HashSet<>(latestHeartbeats.keySet()))
            if (latestHeartbeats.get(clientId).isBefore(now.minus(15, ChronoUnit.SECONDS)))
                latestHeartbeats.remove(clientId);

        String clientId = UUID.randomUUID().toString();
        boolean isMaster = latestHeartbeats.isEmpty();
        latestHeartbeats.put(clientId, now);

        LOGGER.info("Clients: {}", latestHeartbeats);
        if (latestHeartbeats.size() >= currConfig.numClients)
            consensus = new Consensus(now.plus(5, ChronoUnit.SECONDS).toEpochMilli());
        else
            consensus = null;

        return new ReadyResponse(currConfig.musescoreUrl, clientId, isMaster);
    }

    @Override
    public synchronized Consensus pingConsensus(String clientId) {
        latestHeartbeats.put(clientId, Instant.now());
        return consensus;
    }

    @Override
    public synchronized DoneResponse pingDone() {
        return new DoneResponse(done);
    }

    @Override
    public synchronized void uploadAudio(UUID clientId, InputStream audio) throws Exception {
        upload(clientId.toString(), audio, ".m4a");
    }

    @Override
    public synchronized Response uploadVideo(InputStream video) throws Exception {
        upload("zoom", video, ".mp4");
        return Response.ok(String.format("<html><body><a href='/recordings/%s.mp4'>Recording</a></body></html>", recordingId)).build();
    }

    private void upload(String clientId, InputStream data, String extension) throws Exception {
        File newFile = Paths.get("data", recordingId.toString(), clientId + extension).toFile();
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
                    int statusCode = Runtime.getRuntime().exec(new String[] {
                            "/bin/sh",
                            "-c",
                            // https://stackoverflow.com/questions/14498539/how-to-overlay-downmix-two-audio-files-using-ffmpeg
                            String.format("yes | /usr/local/bin/ffmpeg -i %s -i %s -filter_complex amerge=inputs=2 -ac 2 %s",
                                tempFile.getAbsolutePath(), file.getAbsolutePath(), destFile.getAbsolutePath()),
                    }).waitFor();
                    if (statusCode != 0)
                        throw new IllegalStateException("ffmpeg threw error code " + statusCode);
                }

        File outputFile = Paths.get("src", "main", "resources", "public", "recordings", recordingId + ".mp4").toFile();
        for (File file : files)
            if (file.getName().endsWith(".mp4") && destFile.exists()) {
                int statusCode = Runtime.getRuntime().exec(new String[] {
                        "/bin/sh",
                        "-c",
                        // https://video.stackexchange.com/questions/11898/merge-mp4-with-m4a
                        String.format("yes | /usr/local/bin/ffmpeg -i %s -i %s -c:v copy -map 0:v:0 -map 1:a:0 %s",
                            file.getAbsolutePath(), destFile.getAbsolutePath(), outputFile.getAbsolutePath()),
                }).waitFor();
                if (statusCode != 0)
                    throw new IllegalStateException("ffmpeg threw error code " + statusCode);
            }
    }
}
