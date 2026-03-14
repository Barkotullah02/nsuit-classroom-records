package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.DeviceType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTypeRepository extends JpaRepository<DeviceType, Integer> {
    Optional<DeviceType> findByTypeNameIgnoreCase(String typeName);
}
