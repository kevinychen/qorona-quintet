package io.github.kevinychen.qorona;

import java.io.InputStream;
import java.util.UUID;

import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.glassfish.jersey.media.multipart.FormDataParam;

import lombok.Data;

@Path("/")
public interface Service {

    @POST
    @Path("/config")
    @Consumes(MediaType.APPLICATION_JSON)
    void setConfig(Config config);

    @POST
    @Path("/done")
    void setDone();

    @POST
    @Path("/ready")
    @Produces(MediaType.APPLICATION_JSON)
    ReadyResponse ready();

    @POST
    @Path("/ping/{clientId}")
    @Produces(MediaType.APPLICATION_JSON)
    Consensus pingConsensus(@PathParam("clientId") String clientId);

    @POST
    @Path("/ping")
    @Produces(MediaType.APPLICATION_JSON)
    DoneResponse pingDone();

    @POST
    @Path("/upload/audio/{clientId}")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    void uploadAudio(@PathParam("clientId") UUID clientId, @FormDataParam("file") InputStream audio) throws Exception;

    @POST
    @Path("/upload/video")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    Response uploadVideo(@FormDataParam("file") InputStream audio) throws Exception;

    @GET
    @Path("/recording/{recordingId}")
    @Produces("video/mp4")
    Response downloadVideo(@PathParam("recordingId") String recordingId) throws Exception;

    @Data
    public static class Config {

        int numClients = 2;
        String musescoreUrl = "https://musescore.com/user/31796599/scores/5560182";
    }

    @Data
    public static class ReadyResponse {

        final String musescoreUrl;
        final String clientId;
        final boolean master;
    }

    @Data
    public static class Consensus {

        final long startTimeEpochMillis;
    }

    @Data
    public static class DoneResponse {

        final boolean done;
    }
}
