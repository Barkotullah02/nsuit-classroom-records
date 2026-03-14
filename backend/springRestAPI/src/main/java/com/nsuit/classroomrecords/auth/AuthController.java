package com.nsuit.classroomrecords.auth;

import com.nsuit.classroomrecords.api.ApiResponse;
import com.nsuit.classroomrecords.auth.dto.AuthUserDto;
import com.nsuit.classroomrecords.auth.dto.LoginRequest;
import com.nsuit.classroomrecords.auth.dto.LoginResponse;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthController(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        return userRepository.findByUsername(request.username())
                .filter(user -> Boolean.TRUE.equals(user.getActive()))
                .filter(user -> passwordEncoder.matches(request.password(), user.getPasswordHash()))
                .map(this::buildLoginResponse)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.failure("Invalid username or password")));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthUserDto>> me(HttpServletRequest request) {
        String token = extractBearerToken(request);
        if (token == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure("Not authenticated"));
        }

        try {
            Claims claims = jwtService.parseToken(token);
            AuthUserDto user = new AuthUserDto(
                    claims.get("user_id", Integer.class),
                    claims.get("username", String.class),
                    claims.get("full_name", String.class),
                    claims.get("email", String.class),
                    claims.get("role", String.class)
            );
            return ResponseEntity.ok(ApiResponse.success("User authenticated", user));
        } catch (JwtException | IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure("Not authenticated"));
        }
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> logout() {
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully", Map.of()));
    }

    private ResponseEntity<ApiResponse<LoginResponse>> buildLoginResponse(User user) {
        AuthUserDto userDto = AuthUserDto.from(user);
        String token = jwtService.generateToken(userDto);
        return ResponseEntity.ok(ApiResponse.success("Login successful", new LoginResponse(token, userDto)));
    }

    private String extractBearerToken(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        return authorization.substring(7);
    }
}
