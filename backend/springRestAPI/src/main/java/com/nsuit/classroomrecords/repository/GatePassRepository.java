package com.nsuit.classroomrecords.repository;

import com.nsuit.classroomrecords.model.GatePass;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GatePassRepository extends JpaRepository<GatePass, Integer> {
    Optional<GatePass> findByGatePassNumber(String gatePassNumber);
}
