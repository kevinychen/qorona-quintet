package io.github.kevinychen.qorona;

import org.glassfish.jersey.media.multipart.MultiPartFeature;

import io.dropwizard.Application;
import io.dropwizard.Configuration;
import io.dropwizard.assets.AssetsBundle;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;

public class Server extends Application<Configuration> {

    public static void main(String[] args) throws Exception {
        System.setProperty("dw.server.applicationConnectors[0].port", "8100");
        System.setProperty("dw.server.adminConnectors[0].port", "8101");
        new Server().run("server");
    }

    @Override
    public void initialize(Bootstrap<Configuration> bootstrap) {
        bootstrap.addBundle(new AssetsBundle("/public", "/", "index.html"));
    }

    @Override
    public void run(Configuration configuration, Environment environment) throws Exception {
        environment.jersey().register(new MultiPartFeature());
        environment.jersey().setUrlPattern("/api/*");
        environment.jersey().register(new Resource());
    }
}
