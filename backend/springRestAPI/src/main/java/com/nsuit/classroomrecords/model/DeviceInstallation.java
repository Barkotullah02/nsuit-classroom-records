package com.nsuit.classroomrecords.model;

import com.nsuit.classroomrecords.model.enums.InstallationStatus;
import com.nsuit.classroomrecords.model.enums.InstallationType;
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
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "device_installations")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceInstallation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "installation_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", nullable = false)
    private Device device;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "installed_date", nullable = false)
    private LocalDate installedDate;

    @Column(name = "withdrawn_date")
    private LocalDate withdrawnDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "installed_by", nullable = false)
    private User installedBy;

    @Column(name = "team_members", columnDefinition = "TEXT")
    private String teamMembers;

    @Enumerated(EnumType.STRING)
    @Column(name = "installation_type")
    private InstallationType installationType;

    @Column(name = "installer_name", length = 255)
    private String installerName;

    @Column(name = "installer_id", length = 100)
    private String installerId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "withdrawn_by")
    private User withdrawnBy;

    @Column(name = "withdrawer_name", length = 255)
    private String withdrawerName;

    @Column(name = "withdrawer_id", length = 100)
    private String withdrawerId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "data_entry_by")
    private User dataEntryBy;

    @Column(name = "gate_pass_number", length = 100)
    private String gatePassNumber;

    @Column(name = "gate_pass_date")
    private LocalDate gatePassDate;

    @Column(name = "installation_notes", columnDefinition = "TEXT")
    private String installationNotes;

    @Column(name = "withdrawal_notes", columnDefinition = "TEXT")
    private String withdrawalNotes;

    @Column(name = "issue_at_withdrawal", length = 255)
    private String issueAtWithdrawal;

    @Column(name = "storage_location", length = 100)
    private String storageLocation;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private InstallationStatus status;

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
