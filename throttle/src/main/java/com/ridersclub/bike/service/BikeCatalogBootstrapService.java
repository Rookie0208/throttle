package com.ridersclub.bike.service;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class BikeCatalogBootstrapService implements ApplicationRunner {
    private final BikeRegistryService bikeRegistryService;

    @Override
    public void run(ApplicationArguments args) {
        int seeded = bikeRegistryService.ensureSeedData();
        log.info("Ensured curated bike catalog seed data is available. inserted={}", seeded);
    }
}
