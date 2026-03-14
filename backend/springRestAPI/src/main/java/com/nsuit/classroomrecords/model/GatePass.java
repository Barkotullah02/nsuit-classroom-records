package com.nsuit.classroomrecords.model;

import com.nsuit.classroomrecords.model.enums.GatePassStatus;
import com.nsuit.classroomrecords.model.enums.PassDirection;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "gate_passes")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GatePass {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "gate_pass_id")
    private Integer id;

    @Column(name = "gate_pass_number", nullable = false, unique = true, length = 50)
    private String gatePassNumber;

    @Column(name = "gate_pass_date", nullable = false)
    private LocalDate gatePassDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "pass_direction", nullable = false)
    private PassDirection passDirection;

    @Column(name = "gate_pass_time")
    private LocalTime gatePassTime;

    @Column(name = "department", length = 255)
    private String department;

    @Column(name = "gate_name", length = 255)
    private String gateName;

    @Column(name = "vendor_destination", length = 255)
    private String vendorDestination;

    @Column(name = "bearer_name", length = 150)
    private String bearerName;

    @Column(name = "bearer_company", length = 150)
    private String bearerCompany;

    @Column(name = "bearer_contact_no", length = 50)
    private String bearerContactNo;

    @Column(name = "bearer_signature", length = 255)
    private String bearerSignature;

    @Column(name = "bearer_signature_date")
    private LocalDate bearerSignatureDate;

    @Column(name = "security_officer_name", length = 150)
    private String securityOfficerName;

    @Column(name = "security_officer_designation", length = 150)
    private String securityOfficerDesignation;

    @Column(name = "security_officer_ext", length = 50)
    private String securityOfficerExt;

    @Column(name = "security_officer_signature", length = 255)
    private String securityOfficerSignature;

    @Column(name = "security_officer_signature_date")
    private LocalDate securityOfficerSignatureDate;

    @Column(name = "processing_name", length = 150)
    private String processingName;

    @Column(name = "processing_designation", length = 150)
    private String processingDesignation;

    @Column(name = "processing_ext", length = 50)
    private String processingExt;

    @Column(name = "processing_signature", length = 255)
    private String processingSignature;

    @Column(name = "processing_signature_date")
    private LocalDate processingSignatureDate;

    @Column(name = "authorized_name", length = 150)
    private String authorizedName;

    @Column(name = "authorized_designation", length = 150)
    private String authorizedDesignation;

    @Column(name = "authorized_ext", length = 50)
    private String authorizedExt;

    @Column(name = "authorized_signature", length = 255)
    private String authorizedSignature;

    @Column(name = "authorized_signature_date")
    private LocalDate authorizedSignatureDate;

    @Column(name = "consignee_name", columnDefinition = "TEXT")
    private String consigneeName;

    @Column(name = "destination", length = 255)
    private String destination;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "destination_room_id")
    private Room destinationRoom;

    @Column(name = "carrier_name", nullable = false, length = 100)
    private String carrierName;

    @Column(name = "carrier_appointment", length = 100)
    private String carrierAppointment;

    @Column(name = "carrier_department", length = 100)
    private String carrierDepartment;

    @Column(name = "carrier_telephone", length = 50)
    private String carrierTelephone;

    @Column(name = "security_name", length = 100)
    private String securityName;

    @Column(name = "security_appointment", length = 100)
    private String securityAppointment;

    @Column(name = "security_department", length = 100)
    private String securityDepartment;

    @Column(name = "security_telephone", length = 50)
    private String securityTelephone;

    @Column(name = "receiver_name", length = 100)
    private String receiverName;

    @Column(name = "receiver_appointment", length = 100)
    private String receiverAppointment;

    @Column(name = "receiver_department", length = 100)
    private String receiverDepartment;

    @Column(name = "receiver_telephone", length = 50)
    private String receiverTelephone;

    @Column(name = "purpose", nullable = false, length = 100)
    private String purpose;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private GatePassStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @Column(name = "is_deleted")
    private Boolean deleted;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "deleted_by")
    private User deletedBy;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime updatedAt;
}
