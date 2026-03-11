package com.products;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/products")
public class ProductsController {

  private final List<Product> ALL_PRODUCTS = List.of(new Product(1, "bag"), new Product(2, "pencil"));
  @Value("${service.exampleValue}")
  private String exampleValue;

  @GetMapping
  public List<Product> getAllProducts() {
    return ALL_PRODUCTS;
  }

  @GetMapping("/example-value")
  public String getExampleValue() {
    return exampleValue;
  }

}
