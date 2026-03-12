package com.product;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/products")
public class ProductsController {

  private static final Logger log = LoggerFactory.getLogger(ProductsController.class);

  private final List<Product> ALL_PRODUCTS = List.of(new Product(1, "bag"), new Product(2, "pencil"), new Product(3, "bottle"));
  @Value("${service.envInfo}")
  private String envInfo;

  @GetMapping
  public List<Product> getAllProducts() {
    log.info("GET /products -> returning {} products", ALL_PRODUCTS.size());
    return ALL_PRODUCTS;
  }

  @GetMapping("/{id}")
  public Product getById(@PathVariable Integer id) {
    log.info("GET /products/{} -> fetching product", id);
    Product product = ALL_PRODUCTS.get(id);
    log.debug("GET /products/{} -> found: {}", id, product);
    return product;
  }

  @GetMapping("/env-info")
  public String getEnvInfo() {
    log.info("GET /products/env-info -> envInfo={}", envInfo);
    return envInfo;
  }

}
