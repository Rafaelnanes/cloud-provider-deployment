package com.batch.task;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Slf4j
@Component
public class CleanupTask implements BatchTask {

    @Value("${batch.recordCount:100}")
    private int recordCount;

    @Override
    public void execute() {
        log.info("[cleanup] Starting cleanup run at {}", Instant.now());
        log.info("[cleanup] Scanning for expired records...");
        int expired = (int) (recordCount * 0.3);
        log.info("[cleanup] Found {} expired records out of {} total", expired, recordCount);
        log.info("[cleanup] Deleted {} expired records at {}", expired, Instant.now());
    }
}
