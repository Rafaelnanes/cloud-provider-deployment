package com.product.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import net.logstash.logback.argument.StructuredArguments;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class CorrelationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(CorrelationFilter.class);

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().startsWith("/actuator/");
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        MDC.put("http.method", request.getMethod());
        MDC.put("http.path", request.getRequestURI());

        String query = request.getQueryString();
        if (query != null) MDC.put("http.queryString", query);

        String ua = request.getHeader("User-Agent");
        if (ua != null) MDC.put("http.userAgent", ua);

        long startNanos = System.nanoTime();
        try {
            filterChain.doFilter(request, response);
        } finally {
            long latencyMs = (System.nanoTime() - startNanos) / 1_000_000L;
            log.info("HTTP request completed",
                    StructuredArguments.kv("http.status", response.getStatus()),
                    StructuredArguments.kv("http.latencyMs", latencyMs));
            MDC.remove("http.method");
            MDC.remove("http.path");
            MDC.remove("http.queryString");
            MDC.remove("http.userAgent");
        }
    }
}