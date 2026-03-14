package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/gate-passes")
public class GatePassController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;
    private final AuditLogService auditLogService;

    public GatePassController(NamedParameterJdbcTemplate jdbc,
                               CurrentUserService currentUserService,
                               AuditLogService auditLogService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
        this.auditLogService = auditLogService;
    }

    private String str(Map<String, Object> m, String key) {
        Object v = m.get(key);
        return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<?> getGatePasses(
            @RequestParam(required = false) Long gate_pass_id,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        if (gate_pass_id != null) {
            // Single gate pass with devices
            List<Map<String, Object>> rows = jdbc.queryForList(
                    "SELECT gp.*, u_created.full_name as created_by_name " +
                    "FROM gate_passes gp " +
                    "LEFT JOIN users u_created ON gp.created_by = u_created.user_id " +
                    "WHERE gp.gate_pass_id = :id AND gp.is_deleted = FALSE",
                    new MapSqlParameterSource("id", gate_pass_id));
            if (rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Gate pass not found");

            Map<String, Object> gp = rows.get(0);

            List<Map<String, Object>> devices = jdbc.queryForList(
                    "SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model, d.serial_number, " +
                    "current_room.room_number as current_room_number, current_room.room_name as current_room_name " +
                    "FROM gate_pass_devices gpd " +
                    "JOIN devices d ON gpd.device_id = d.device_id " +
                    "JOIN device_types dt ON d.type_id = dt.type_id " +
                    "JOIN device_brands db ON d.brand_id = db.brand_id " +
                    "LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE " +
                    "LEFT JOIN rooms current_room ON di.room_id = current_room.room_id " +
                    "WHERE gpd.gate_pass_id = :id",
                    new MapSqlParameterSource("id", gate_pass_id));
            gp.put("devices", devices);

            return ApiResponse.success("Gate pass retrieved successfully", List.of(gp));
        } else {
            List<Map<String, Object>> list = jdbc.queryForList(
                    "SELECT gp.gate_pass_id, gp.gate_pass_number, gp.gate_pass_date, gp.pass_direction, " +
                    "gp.department, gp.gate_name, gp.vendor_destination, gp.bearer_name, " +
                    "gp.consignee_name, gp.destination, gp.carrier_name, gp.status, " +
                    "u_created.full_name as created_by_name, gp.created_at, " +
                    "COUNT(gpd.device_id) as device_count " +
                    "FROM gate_passes gp " +
                    "LEFT JOIN gate_pass_devices gpd ON gp.gate_pass_id = gpd.gate_pass_id " +
                    "LEFT JOIN users u_created ON gp.created_by = u_created.user_id " +
                    "WHERE gp.is_deleted = FALSE " +
                    "GROUP BY gp.gate_pass_id ORDER BY gp.created_at DESC",
                    Map.of());
            return ApiResponse.success("Gate passes retrieved successfully", list);
        }
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createGatePass(@RequestBody Map<String, Object> data,
                                                            HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        // Validate required
        if (data.get("devices") == null || !(data.get("devices") instanceof List) ||
                ((List<?>) data.get("devices")).isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Missing required fields");
        }
        if (str(data, "gate_pass_number") == null || str(data, "gate_pass_date") == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Missing required fields");
        }

        // Field mapping with backward compatibility
        String passDirection = str(data, "pass_direction");
        if (!"incoming".equals(passDirection) && !"outgoing".equals(passDirection)) passDirection = "outgoing";

        String department        = str(data, "department")        != null ? str(data, "department")        : str(data, "consignee_name");
        String vendorDestination = str(data, "vendor_destination") != null ? str(data, "vendor_destination") : str(data, "destination");
        String bearerName        = str(data, "bearer_name")        != null ? str(data, "bearer_name")        : str(data, "carrier_name");
        String bearerCompany     = str(data, "bearer_company")     != null ? str(data, "bearer_company")     : str(data, "carrier_department");
        String bearerContactNo   = str(data, "bearer_contact_no")  != null ? str(data, "bearer_contact_no")  : str(data, "carrier_telephone");
        String securityOfficerName = str(data, "security_officer_name") != null ? str(data, "security_officer_name") : str(data, "security_name");
        String securityOfficerDesig = str(data, "security_officer_designation") != null ? str(data, "security_officer_designation") : str(data, "security_appointment");
        String processingName    = str(data, "processing_name")    != null ? str(data, "processing_name")    : str(data, "receiver_name");
        String processingDesig   = str(data, "processing_designation") != null ? str(data, "processing_designation") : str(data, "receiver_appointment");

        if (department == null || vendorDestination == null || bearerName == null ||
                bearerCompany == null || bearerContactNo == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Missing required fields");
        }

        // Check duplicate gate_pass_number
        Long existing = jdbc.queryForObject(
                "SELECT COUNT(*) FROM gate_passes WHERE gate_pass_number = :gpn AND is_deleted = FALSE",
                new MapSqlParameterSource("gpn", str(data, "gate_pass_number")), Long.class);
        if (existing != null && existing > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Gate pass number already exists");
        }

        // Compat fields
        String consigneeName     = str(data, "consignee_name")     != null ? str(data, "consignee_name")     : department;
        String destination       = str(data, "destination")        != null ? str(data, "destination")        : vendorDestination;
        String carrierName       = str(data, "carrier_name")       != null ? str(data, "carrier_name")       : bearerName;
        String carrierDepartment = str(data, "carrier_department") != null ? str(data, "carrier_department") : bearerCompany;
        String carrierTelephone  = str(data, "carrier_telephone")  != null ? str(data, "carrier_telephone")  : bearerContactNo;
        String securityDept      = str(data, "security_department") != null ? str(data, "security_department") : "Duty Security Officer";
        String purpose           = str(data, "purpose")            != null ? str(data, "purpose")            : "Other";

        String sql = "INSERT INTO gate_passes " +
                "(gate_pass_number, gate_pass_date, pass_direction, gate_pass_time, department, gate_name, vendor_destination, " +
                "bearer_name, bearer_company, bearer_contact_no, bearer_signature, bearer_signature_date, " +
                "security_officer_name, security_officer_designation, security_officer_ext, security_officer_signature, security_officer_signature_date, " +
                "processing_name, processing_designation, processing_ext, processing_signature, processing_signature_date, " +
                "authorized_name, authorized_designation, authorized_ext, authorized_signature, authorized_signature_date, " +
                "consignee_name, destination, carrier_name, carrier_appointment, carrier_department, carrier_telephone, " +
                "security_name, security_appointment, security_department, security_telephone, " +
                "receiver_name, receiver_appointment, receiver_department, receiver_telephone, " +
                "purpose, remarks, created_by, status) " +
                "VALUES " +
                "(:gate_pass_number, :gate_pass_date, :pass_direction, :gate_pass_time, :department, :gate_name, :vendor_destination, " +
                ":bearer_name, :bearer_company, :bearer_contact_no, :bearer_signature, :bearer_signature_date, " +
                ":security_officer_name, :security_officer_designation, :security_officer_ext, :security_officer_signature, :security_officer_signature_date, " +
                ":processing_name, :processing_designation, :processing_ext, :processing_signature, :processing_signature_date, " +
                ":authorized_name, :authorized_designation, :authorized_ext, :authorized_signature, :authorized_signature_date, " +
                ":consignee_name, :destination, :carrier_name, :carrier_appointment, :carrier_department, :carrier_telephone, " +
                ":security_name, :security_appointment, :security_department, :security_telephone, " +
                ":receiver_name, :receiver_appointment, :receiver_department, :receiver_telephone, " +
                ":purpose, :remarks, :created_by, 'active')";

        MapSqlParameterSource p = new MapSqlParameterSource()
                .addValue("gate_pass_number", str(data, "gate_pass_number"))
                .addValue("gate_pass_date", str(data, "gate_pass_date"))
                .addValue("pass_direction", passDirection)
                .addValue("gate_pass_time", str(data, "gate_pass_time"))
                .addValue("department", department)
                .addValue("gate_name", str(data, "gate_name"))
                .addValue("vendor_destination", vendorDestination)
                .addValue("bearer_name", bearerName)
                .addValue("bearer_company", bearerCompany)
                .addValue("bearer_contact_no", bearerContactNo)
                .addValue("bearer_signature", str(data, "bearer_signature"))
                .addValue("bearer_signature_date", str(data, "bearer_signature_date"))
                .addValue("security_officer_name", securityOfficerName)
                .addValue("security_officer_designation", securityOfficerDesig)
                .addValue("security_officer_ext", str(data, "security_officer_ext"))
                .addValue("security_officer_signature", str(data, "security_officer_signature"))
                .addValue("security_officer_signature_date", str(data, "security_officer_signature_date"))
                .addValue("processing_name", processingName)
                .addValue("processing_designation", processingDesig)
                .addValue("processing_ext", str(data, "processing_ext"))
                .addValue("processing_signature", str(data, "processing_signature"))
                .addValue("processing_signature_date", str(data, "processing_signature_date"))
                .addValue("authorized_name", str(data, "authorized_name"))
                .addValue("authorized_designation", str(data, "authorized_designation"))
                .addValue("authorized_ext", str(data, "authorized_ext"))
                .addValue("authorized_signature", str(data, "authorized_signature"))
                .addValue("authorized_signature_date", str(data, "authorized_signature_date"))
                .addValue("consignee_name", consigneeName)
                .addValue("destination", destination)
                .addValue("carrier_name", carrierName)
                .addValue("carrier_appointment", str(data, "carrier_appointment"))
                .addValue("carrier_department", carrierDepartment)
                .addValue("carrier_telephone", carrierTelephone)
                .addValue("security_name", str(data, "security_name"))
                .addValue("security_appointment", str(data, "security_appointment"))
                .addValue("security_department", securityDept)
                .addValue("security_telephone", str(data, "security_telephone"))
                .addValue("receiver_name", str(data, "receiver_name"))
                .addValue("receiver_appointment", str(data, "receiver_appointment"))
                .addValue("receiver_department", str(data, "receiver_department"))
                .addValue("receiver_telephone", str(data, "receiver_telephone"))
                .addValue("purpose", purpose)
                .addValue("remarks", str(data, "remarks"))
                .addValue("created_by", user.getId());

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(sql, p, keyHolder);
        long gatePassId = keyHolder.getKey().longValue();

        // Insert devices into junction table
        @SuppressWarnings("unchecked")
        List<Object> devices = (List<Object>) data.get("devices");
        for (Object deviceIdObj : devices) {
            long devId = Long.parseLong(deviceIdObj.toString());
            jdbc.update("INSERT INTO gate_pass_devices (gate_pass_id, device_id) VALUES (:gp, :d)",
                    new MapSqlParameterSource("gp", gatePassId).addValue("d", devId));
        }

        auditLogService.log(user, "INSERT", "gate_passes", (int) gatePassId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("gate_pass_id", gatePassId);
        result.put("gate_pass_number", str(data, "gate_pass_number"));
        return ApiResponse.success("Gate pass created successfully", result);
    }

    @DeleteMapping
    public ApiResponse<Object> deleteGatePass(@RequestBody Map<String, Object> body,
                                               HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        Object idObj = body.get("gate_pass_id");
        if (idObj == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Gate pass ID is required");
        long id = Long.parseLong(idObj.toString());

        jdbc.update("UPDATE gate_passes SET is_deleted = TRUE, deleted_at = CURRENT_TIMESTAMP, deleted_by = :uid WHERE gate_pass_id = :id",
                new MapSqlParameterSource("uid", user.getId()).addValue("id", id));
        auditLogService.log(user, "DELETE", "gate_passes", (int) id);

        return ApiResponse.success("Gate pass deleted successfully", null);
    }
}
