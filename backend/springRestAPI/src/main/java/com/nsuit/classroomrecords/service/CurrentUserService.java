package com.nsuit.classroomrecords.service;

import com.nsuit.classroomrecords.auth.JwtService;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.model.enums.UserRole;
import com.nsuit.classroomrecords.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class CurrentUserService {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public CurrentUserService(JwtService jwtService, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    public User requireAuth(HttpServletRequest request) {
        String token = extractBearerToken(request);
        if (token == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Authentication required");
        }

        try {
            Claims claims = jwtService.parseToken(token);
            Integer userId = claims.get("user_id", Integer.class);
            return userRepository.findById(userId)
                    .filter(user -> Boolean.TRUE.equals(user.getActive()))
                    .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Authentication required"));
        } catch (JwtException | IllegalArgumentException ex) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Authentication required");
        }
    }

    public User requireAdmin(HttpServletRequest request) {
        User user = requireAuth(request);
        if (!(user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Admin access required");
        }
        return user;
    }

    public User requireCreate(HttpServletRequest request) {
        User user = requireAuth(request);
        if (!(user.getRole() == UserRole.staff || user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Insufficient permissions to create records");
        }
        return user;
    }

    private String extractBearerToken(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        return authorization.substring(7);
    }
}
