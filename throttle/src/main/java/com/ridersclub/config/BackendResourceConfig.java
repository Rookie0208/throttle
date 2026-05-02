package com.ridersclub.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "backend.resource")
public class BackendResourceConfig {
    private SubscriptionResource subscription = new SubscriptionResource();

    @Getter
    @Setter
    public static class SubscriptionResource {
        private int freePlanMaxBikes = 3;
        private int activePlanBikeLimit = 999;
    }
}
