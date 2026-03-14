package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.DeviceInstallation;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceInstallationRepository extends JpaRepository<DeviceInstallation, Integer> {
    List<DeviceInstallation> findByDevice_Id(Integer deviceId);
    List<DeviceInstallation> findByRoom_Id(Integer roomId);
}
