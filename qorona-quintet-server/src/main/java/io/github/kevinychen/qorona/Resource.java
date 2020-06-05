package io.github.kevinychen.qorona;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.UUID;

import javax.ws.rs.ServiceUnavailableException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Resource implements Service {

    private static final Logger LOGGER = LoggerFactory.getLogger(Resource.class);

    private volatile Config currConfig;
    private volatile Consensus consensus;
    private Map<UUID, Instant> latestHeartbeats = new HashMap<>();

    @Override
    public synchronized void setConfig(Config config) {
        LOGGER.info("Updating config: {}", config);
        currConfig = config;
        latestHeartbeats.clear();
    }

    @Override
    public synchronized ReadyResponse ready() {
        if (currConfig == null)
            throw new ServiceUnavailableException();

        Instant now = Instant.now();

        for (UUID client : new HashSet<>(latestHeartbeats.keySet()))
            if (latestHeartbeats.get(client).isBefore(now.minus(5, ChronoUnit.SECONDS)))
                latestHeartbeats.remove(client);

        UUID client = UUID.randomUUID();
        boolean isHost = latestHeartbeats.isEmpty();
        latestHeartbeats.put(client, now);

        LOGGER.info("Clients: {}", latestHeartbeats);
        if (latestHeartbeats.size() >= currConfig.numClients)
            consensus = new Consensus(now.plus(5, ChronoUnit.SECONDS).toEpochMilli());
        else
            consensus = null;

        return new ReadyResponse(currConfig.musescoreUrl, client, isHost);
    }

    @Override
    public synchronized Consensus pingConsensus(UUID client) {
        latestHeartbeats.put(client, Instant.now());
        return consensus;
    }
}
