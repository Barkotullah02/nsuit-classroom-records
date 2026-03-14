package com.nsuit.classroomrecords.auth.dto;

public record LoginResponse(String token, AuthUserDto user) {
}
