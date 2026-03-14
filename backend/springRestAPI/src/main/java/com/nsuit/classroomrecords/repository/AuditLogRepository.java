package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuditLogRepository extends JpaRepository<AuditLog, Integer> {
}
