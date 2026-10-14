package com.example.cleanbooking;

import java.util.Map;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// 프론트·백엔드·DB 연결 확인용
@RestController
@RequiredArgsConstructor
public class PingController {

	private final JdbcTemplate jdbcTemplate;

	@GetMapping("/api/ping")
	public Map<String, String> ping() {
		String dbTime = jdbcTemplate.queryForObject("SELECT NOW()", String.class);
		return Map.of("message", "pong", "dbTime", dbTime);
	}
}
