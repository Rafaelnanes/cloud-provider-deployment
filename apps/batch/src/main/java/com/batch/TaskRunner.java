package com.batch;

import com.batch.task.BatchTask;
import com.batch.task.CleanupTask;
import com.batch.task.ReportTask;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class TaskRunner {

    private final ReportTask reportTask;
    private final CleanupTask cleanupTask;

    @Value("${batch.taskType}")
    private String taskType;

    public TaskRunner(ReportTask reportTask, CleanupTask cleanupTask) {
        this.reportTask = reportTask;
        this.cleanupTask = cleanupTask;
    }

    public void execute() {
        log.info("==> Dispatching task type: '{}'", taskType);
        BatchTask task = switch (taskType.toLowerCase()) {
            case "report"  -> reportTask;
            case "cleanup" -> cleanupTask;
            default -> throw new IllegalArgumentException(
                "Unknown TASK_TYPE: '" + taskType + "'. Valid values: report, cleanup"
            );
        };
        task.execute();
    }
}
