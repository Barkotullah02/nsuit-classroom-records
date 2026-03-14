package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.ClassroomSupportRecord;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClassroomSupportRecordRepository extends JpaRepository<ClassroomSupportRecord, Integer> {
}
