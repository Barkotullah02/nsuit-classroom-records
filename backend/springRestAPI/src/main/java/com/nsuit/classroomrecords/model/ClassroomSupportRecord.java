package com.nsuit.classroomrecords.model;

import com.nsuit.classroomrecords.model.enums.SupportIssueType;
import com.nsuit.classroomrecords.model.enums.SupportPriority;
import com.nsuit.classroomrecords.model.enums.SupportRecordStatus;
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
@Table(name = "classroom_support_records")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassroomSupportRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "support_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private SupportTeamMember member;

    @Column(name = "support_date", nullable = false)
    private LocalDate supportDate;

    @Column(name = "support_time", nullable = false)
    private LocalTime supportTime;

    @Column(name = "location", nullable = false, length = 100)
    private String location;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id")
    private Room room;

    @Column(name = "support_description", nullable = false, columnDefinition = "TEXT")
    private String supportDescription;

    @Enumerated(EnumType.STRING)
    @Column(name = "issue_type")
    private SupportIssueType issueType;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority")
    private SupportPriority priority;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private SupportRecordStatus status;

    @Column(name = "devices_involved", columnDefinition = "TEXT")
    private String devicesInvolved;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "faculty_name", length = 100)
    private String facultyName;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

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
