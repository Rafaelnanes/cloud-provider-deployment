package com.user;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class ProductsClient {

  private final RestClient restClient;

  public ProductsClient(@Value("${service.productsUrl}") String productsUrl) {
    this.restClient = RestClient.builder().baseUrl(productsUrl).build();
  }

  public Product getById(Integer id) {
    return restClient.get().uri("/products/{id}", id).retrieve().body(Product.class);
  }

}
