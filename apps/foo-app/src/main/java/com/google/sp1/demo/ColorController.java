package com.google.sp1.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.atomic.AtomicLong;


@RestController
public class ColorController {

    @GetMapping("/color")
    public String color() {
        return "orange";
    }

}