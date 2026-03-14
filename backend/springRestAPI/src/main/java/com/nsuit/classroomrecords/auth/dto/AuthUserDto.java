package com.nsuit.classroomrecords.auth.dto;

import com.nsuit.classroomrecords.model.User;

public record AuthUserDto(
        Integer user_id,
        String username,
        String full_name,
        String email,
        String role) {

    public static AuthUserDto from(User user) {
        return new AuthUserDto(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getEmail(),
                user.getRole() != null ? user.getRole().name().toLowerCase() : null
        );
    }
}
