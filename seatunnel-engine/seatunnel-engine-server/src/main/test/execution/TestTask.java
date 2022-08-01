/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package execution;

import org.apache.seatunnel.engine.server.execution.ProgressState;
import org.apache.seatunnel.engine.server.execution.Task;

import com.hazelcast.logging.ILogger;
import lombok.NonNull;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * For test use, only print logs
 */
public class TestTask implements Task {

    AtomicBoolean stop;
    private final ILogger logger;

    public TestTask(AtomicBoolean stop, ILogger logger){
        this.stop = stop;
        this.logger = logger;
    }

    @NonNull
    @Override
    public ProgressState call() {
        ProgressState progressState;
        if (!stop.get()){
            logger.info("TestTasklet is running");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
            }
            progressState = ProgressState.MADE_PROGRESS;
        }else {
            progressState = ProgressState.DONE;
        }
        return progressState;
    }

    @NonNull
    @Override
    public Long getTaskID() {
        return 1L;
    }
}