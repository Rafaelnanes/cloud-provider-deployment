package com.batch;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;

@Slf4j
@SpringBootApplication
public class BatchApplication implements CommandLineRunner {

    @Autowired
    private ApplicationContext context;

    @Autowired
    private TaskRunner taskRunner;

    public static void main(String[] args) {
        SpringApplication.run(BatchApplication.class, args);
    }

    @Override
    public void run(String... args) {
        log.info("==> Batch job starting");
        try {
            taskRunner.execute();
            log.info("==> Batch job completed successfully");
        } catch (Exception e) {
            log.error("==> Batch job failed: {}", e.getMessage(), e);
            System.exit(SpringApplication.exit(context, () -> 1));
        }
        System.exit(SpringApplication.exit(context, () -> 0));
    }
}
