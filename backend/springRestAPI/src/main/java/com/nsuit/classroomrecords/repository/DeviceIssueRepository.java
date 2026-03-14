package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.DeviceIssue;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceIssueRepository extends JpaRepository<DeviceIssue, Integer> {
}
