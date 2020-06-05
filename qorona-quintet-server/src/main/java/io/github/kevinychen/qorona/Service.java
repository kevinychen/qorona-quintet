package io.github.kevinychen.qorona;

import java.util.UUID;

import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import lombok.Data;

@Path("/")
public interface Service {

    @POST
    @Path("/config")
    @Consumes(MediaType.APPLICATION_JSON)
    void setConfig(Config config);

    @POST
    @Path("/ready")
    @Produces(MediaType.APPLICATION_JSON)
    ReadyResponse ready();

    @POST
    @Path("/ping/{client}")
    @Produces(MediaType.APPLICATION_JSON)
    Consensus pingConsensus(@PathParam("client") UUID client);

    @Data
    public static class Config {

        int numClients;
        String musescoreUrl;
    }

    @Data
    public static class ReadyResponse {

        final String musescoreUrl;
        final UUID client;
        final boolean host;
    }

    @Data
    public static class Consensus {

        final long timestampEpochMillis;
    }
}
