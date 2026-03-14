package com.nsuit.classroomrecords.api;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayOutputStream;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/generate-qr")
public class GenerateQrController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public GenerateQrController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ResponseEntity<?> generateQr(
            @RequestParam(required = false) Long device_id,
            HttpServletRequest request) {

        currentUserService.requireAuth(request);

        if (device_id == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Device ID is required");
        }

        // Get device info with current installation
        List<Map<String, Object>> devices = jdbc.queryForList(
                "SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, " +
                "d.model, d.serial_number, d.purchase_date, d.notes, " +
                "r.room_number, r.room_name, r.building, " +
                "di.installed_date, di.installation_notes " +
                "FROM devices d " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE " +
                "LEFT JOIN rooms r ON di.room_id = r.room_id " +
                "WHERE d.device_id = :device_id AND d.is_deleted = FALSE",
                new MapSqlParameterSource("device_id", device_id));

        if (devices.isEmpty()) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Device not found");
        }

        Map<String, Object> device = devices.get(0);

        // Get installation history
        List<Map<String, Object>> history = jdbc.queryForList(
                "SELECT r.room_number, r.room_name, r.building, " +
                "di.installed_date, di.withdrawn_date, di.status " +
                "FROM device_installations di " +
                "JOIN rooms r ON di.room_id = r.room_id " +
                "WHERE di.device_id = :device_id AND di.is_deleted = FALSE " +
                "ORDER BY di.installed_date DESC",
                new MapSqlParameterSource("device_id", device_id));

        // Build QR text — matches PHP format exactly
        StringBuilder qr = new StringBuilder();
        qr.append("DEVICE INFORMATION\n");
        qr.append("==================\n\n");
        qr.append("Device UID: ").append(str(device, "device_unique_id")).append("\n");
        qr.append("Type: ").append(orNA(str(device, "type_name"))).append("\n");
        qr.append("Brand: ").append(orNA(str(device, "brand_name"))).append("\n");
        qr.append("Model: ").append(orNA(str(device, "model"))).append("\n");
        qr.append("Serial: ").append(orNA(str(device, "serial_number"))).append("\n");
        qr.append("Purchase Date: ").append(orNA(str(device, "purchase_date"))).append("\n\n");

        qr.append("CURRENT LOCATION\n");
        qr.append("----------------\n");
        if (device.get("room_number") != null) {
            String building = str(device, "building");
            String prefix = (building != null && !building.isBlank()) ? building + " " : "";
            qr.append("Room: ").append(prefix).append(str(device, "room_number"))
              .append(" - ").append(str(device, "room_name")).append("\n");
            qr.append("Installed: ").append(orNA(str(device, "installed_date"))).append("\n");
        } else {
            qr.append("Status: Not Installed\n");
        }

        String notes = str(device, "notes");
        String installNotes = str(device, "installation_notes");
        if ((notes != null && !notes.isBlank()) || (installNotes != null && !installNotes.isBlank())) {
            qr.append("\nNOTES/ISSUES\n");
            qr.append("------------\n");
            qr.append((notes != null && !notes.isBlank()) ? notes : installNotes);
            qr.append("\n");
        }

        if (!history.isEmpty()) {
            qr.append("\nINSTALLATION HISTORY\n");
            qr.append("--------------------\n");
            for (Map<String, Object> h : history) {
                String b = str(h, "building");
                String room = ((b != null && !b.isBlank()) ? b + " " : "") +
                        str(h, "room_number") + " - " + str(h, "room_name");
                qr.append("• ").append(room).append("\n");
                String withdrawn = str(h, "withdrawn_date");
                qr.append("  ").append(str(h, "installed_date"))
                  .append(" → ").append(withdrawn != null ? withdrawn : "Current").append("\n");
            }
        } else {
            qr.append("\nNo previous installation history.\n");
        }

        // Generate QR code PNG using ZXing
        try {
            QRCodeWriter writer = new QRCodeWriter();
            EnumMap<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
            hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.L);
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
            hints.put(EncodeHintType.MARGIN, 2);

            BitMatrix matrix = writer.encode(qr.toString(), BarcodeFormat.QR_CODE, 500, 500, hints);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(matrix, "PNG", out);
            byte[] png = out.toByteArray();

            String uid = str(device, "device_unique_id");
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.IMAGE_PNG);
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"device-" + uid + "-qr.png\"");
            headers.setContentLength(png.length);

            return new ResponseEntity<>(png, headers, HttpStatus.OK);

        } catch (Exception e) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate QR code: " + e.getMessage());
        }
    }

    private String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v != null ? v.toString() : null;
    }

    private String orNA(String v) {
        return (v != null && !v.isBlank()) ? v : "N/A";
    }
}
