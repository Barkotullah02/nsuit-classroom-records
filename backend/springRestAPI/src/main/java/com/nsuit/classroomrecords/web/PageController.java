package com.nsuit.classroomrecords.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * MVC Page Controller
 * Serves Thymeleaf HTML template pages at clean URL routes.
 * Client-side JS (auth.js + utils.js) handles JWT authentication checks.
 */
@Controller
public class PageController {

    @GetMapping("/")
    public String index() {
        return "redirect:/login";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/dashboard")
    public String dashboard() {
        return "dashboard";
    }

    @GetMapping("/devices")
    public String devices() {
        return "devices";
    }

    @GetMapping("/rooms")
    public String rooms() {
        return "rooms";
    }

    @GetMapping("/installations")
    public String installations() {
        return "installations";
    }

    @GetMapping("/users")
    public String users() {
        return "users";
    }

    @GetMapping("/gate-passes")
    public String gatePasses() {
        return "gate-passes";
    }

    @GetMapping("/create-gate-pass")
    public String createGatePass() {
        return "create-gate-pass";
    }

    @GetMapping("/device-history")
    public String deviceHistory() {
        return "device-history";
    }

    @GetMapping("/room-history")
    public String roomHistory() {
        return "room-history";
    }

    @GetMapping("/building-device-history")
    public String buildingDeviceHistory() {
        return "building-device-history";
    }

    @GetMapping("/deleted-items")
    public String deletedItems() {
        return "deleted-items";
    }

    @GetMapping("/import-data")
    public String importData() {
        return "import-data";
    }

    @GetMapping("/invalid-installation-dates")
    public String invalidInstallationDates() {
        return "invalid-installation-dates";
    }

    @GetMapping("/classroom-support")
    public String classroomSupport() {
        return "classroom-support";
    }

    @GetMapping("/blog")
    public String blog() {
        return "blog";
    }

    @GetMapping("/blog-post")
    public String blogPost() {
        return "blog-post";
    }

    @GetMapping("/blog-admin")
    public String blogAdmin() {
        return "blog-admin";
    }

    @GetMapping("/qr-view")
    public String qrView() {
        return "qr-view";
    }

    @GetMapping({"/gate-pass-print", "/gate-pass"})
    public String gatePassPrint() {
        return "gate-pass";
    }

    @GetMapping("/gate-pass-standalone")
    public String gatePassStandalone() {
        return "gate-pass-standalone";
    }
}
