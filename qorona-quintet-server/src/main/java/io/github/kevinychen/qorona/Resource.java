package io.github.kevinychen.qorona;

import java.io.File;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.UUID;

import javax.ws.rs.core.Response;
import javax.ws.rs.core.StreamingOutput;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.io.Files;

public class Resource implements Service {

    private static final Logger LOGGER = LoggerFactory.getLogger(Resource.class);
    private static final String[] ENVP = new String[] { "PATH=/usr/local/bin:/usr/bin" };

    private volatile Config currConfig = new Config();
    private volatile String recordingId = UUID.randomUUID().toString();
    private volatile boolean done;
    private volatile Consensus consensus;
    private Map<String, Instant> latestHeartbeats = new HashMap<>();

    @Override
    public synchronized void setConfig(Config config) {
        LOGGER.info("Updating config: {}", config);
        currConfig = config;
        recordingId = UUID.randomUUID().toString();
        done = false;
        latestHeartbeats.clear();
    }

    @Override
    public synchronized void setDone(boolean done) {
        this.done = done;
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
        uploadAndMerge(clientId.toString(), audio, ".m4a");
    }

    @Override
    public synchronized Response uploadVideo(InputStream video) throws Exception {
        uploadAndMerge("zoom", video, ".mp4");
        return Response.seeOther(new URI("/recording.html#" + recordingId))
                .build();
    }

    @Override
    public synchronized Response downloadVideo(String recordingId) throws Exception {
        // https://stackoverflow.com/questions/24716357/jersey-client-to-download-and-save-file
        return Response.ok((StreamingOutput) output -> Files.copy(Paths.get("data", recordingId, "merged_video.mp4").toFile(), output))
            .build();
    }

    private void uploadAndMerge(String clientId, InputStream data, String extension) throws Exception {
        File newFile = Paths.get("data", recordingId.toString(), clientId + extension).toFile();
        FileUtils.copyInputStreamToFile(data, newFile);

        File tempFile = new File(newFile.getParentFile(), "temp.m4a");
        File mergedAudioFile = new File(newFile.getParentFile(), "merged_audio.m4a");
        tempFile.delete();
        mergedAudioFile.delete();

        File[] files = newFile.getParentFile().listFiles();
        for (File file : files)
            if (file.getName().endsWith(".m4a"))
                if (!mergedAudioFile.exists()) {
                    Files.copy(file, mergedAudioFile);
                } else {
                    Files.copy(mergedAudioFile, tempFile);
                    int statusCode = Runtime.getRuntime().exec(new String[] {
                            "/bin/sh",
                            "-c",
                            // https://stackoverflow.com/questions/14498539/how-to-overlay-downmix-two-audio-files-using-ffmpeg
                            String.format("yes | ffmpeg -i %s -i %s -filter_complex amerge=inputs=2 -ac 2 %s",
                                tempFile.getAbsolutePath(), file.getAbsolutePath(), mergedAudioFile.getAbsolutePath()),
                    }, ENVP).waitFor();
                    if (statusCode != 0)
                        throw new IllegalStateException("ffmpeg threw error code " + statusCode);
                }

        File mergedVideoFile = new File(newFile.getParentFile(), "merged_video.mp4");
        for (File file : files)
            if (file.getName().endsWith(".mp4") && mergedAudioFile.exists()) {
                int statusCode = Runtime.getRuntime().exec(new String[] {
                        "/bin/sh",
                        "-c",
                        // https://video.stackexchange.com/questions/11898/merge-mp4-with-m4a
                        String.format("yes | ffmpeg -i %s -i %s -c:v copy -map 0:v:0 -map 1:a:0 %s",
                            file.getAbsolutePath(), mergedAudioFile.getAbsolutePath(), mergedVideoFile.getAbsolutePath()),
                }, ENVP).waitFor();
                if (statusCode != 0)
                    throw new IllegalStateException("ffmpeg threw error code " + statusCode);
            }
    }
}
