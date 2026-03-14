package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.DeviceBrand;
import com.nsuit.classroomrecords.model.DeviceType;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.repository.DeviceBrandRepository;
import com.nsuit.classroomrecords.repository.DeviceTypeRepository;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/metadata")
public class MetadataController {

    private final CurrentUserService currentUserService;
    private final DeviceTypeRepository deviceTypeRepository;
    private final DeviceBrandRepository deviceBrandRepository;

    public MetadataController(
            CurrentUserService currentUserService,
            DeviceTypeRepository deviceTypeRepository,
            DeviceBrandRepository deviceBrandRepository) {
        this.currentUserService = currentUserService;
        this.deviceTypeRepository = deviceTypeRepository;
        this.deviceBrandRepository = deviceBrandRepository;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getMetadata(HttpServletRequest request) {
        currentUserService.requireAuth(request);
        List<Map<String, Object>> types = deviceTypeRepository.findAll().stream()
                .sorted((a, b) -> a.getTypeName().compareToIgnoreCase(b.getTypeName()))
                .map(type -> Map.<String, Object>of(
                        "type_id", type.getId(),
                        "type_name", type.getTypeName(),
                        "description", type.getDescription() == null ? "" : type.getDescription()))
                .toList();
        List<Map<String, Object>> brands = deviceBrandRepository.findAll().stream()
                .sorted((a, b) -> a.getBrandName().compareToIgnoreCase(b.getBrandName()))
                .map(brand -> Map.<String, Object>of(
                        "brand_id", brand.getId(),
                        "brand_name", brand.getBrandName()))
                .toList();

        return ApiResponse.success("Metadata retrieved successfully", Map.of(
                "types", types,
                "brands", brands,
                "device_statuses", List.of(),
                "installation_types", List.of(
                        Map.of("value", "NEW_INSTALLATION", "label", "New Installation"),
                        Map.of("value", "REPAIRED", "label", "Repaired Device"),
                        Map.of("value", "OLD_REINSTALL", "label", "Old Device Reinstall")
                )
        ));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Integer>>> createMetadata(
            HttpServletRequest request,
            @RequestBody Map<String, String> payload) {
        User user = currentUserService.requireAdmin(request);
        if (user == null) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Unauthorized. Admin access required.");
        }

        String type = trim(payload.get("type"));
        if (type == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Type parameter is required (brand or device_type)");
        }

        if ("brand".equals(type)) {
            String brandName = trim(payload.get("brand_name"));
            if (brandName == null) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Brand name is required");
            }
            DeviceBrand saved = deviceBrandRepository.save(DeviceBrand.builder().brandName(brandName).build());
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Brand created successfully", Map.of("brand_id", saved.getId())));
        }

        if ("device_type".equals(type)) {
            String typeName = trim(payload.get("type_name"));
            if (typeName == null) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Type name is required");
            }
            DeviceType saved = deviceTypeRepository.save(DeviceType.builder()
                    .typeName(typeName)
                    .description(trim(payload.get("description")))
                    .build());
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Device type created successfully", Map.of("type_id", saved.getId())));
        }

        throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid type parameter");
    }

    private String trim(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
