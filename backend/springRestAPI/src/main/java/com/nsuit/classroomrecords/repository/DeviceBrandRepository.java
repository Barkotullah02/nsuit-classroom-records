package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.DeviceBrand;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceBrandRepository extends JpaRepository<DeviceBrand, Integer> {
    Optional<DeviceBrand> findByBrandNameIgnoreCase(String brandName);
}
