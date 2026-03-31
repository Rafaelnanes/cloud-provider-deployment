package com.batch.task;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Slf4j
@Component
public class ReportTask implements BatchTask {

    @Value("${batch.recordCount:100}")
    private int recordCount;

    @Override
    public void execute() {
        log.info("[report] Starting processing report at {}", Instant.now());
        for (int i = 1; i <= recordCount; i++) {
            log.debug("[report] Processing record {}/{}", i, recordCount);
        }
        log.info("[report] Report complete — {} records processed at {}", recordCount, Instant.now());
    }
}
