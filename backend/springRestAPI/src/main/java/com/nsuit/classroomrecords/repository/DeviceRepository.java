package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.Device;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceRepository extends JpaRepository<Device, Integer> {
    Optional<Device> findByDeviceUniqueId(String deviceUniqueId);
    boolean existsByDeviceUniqueId(String deviceUniqueId);
}
