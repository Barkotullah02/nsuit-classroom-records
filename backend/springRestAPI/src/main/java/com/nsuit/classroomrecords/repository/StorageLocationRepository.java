package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.StorageLocation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StorageLocationRepository extends JpaRepository<StorageLocation, Integer> {
}
