package com.user;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.util.CollectionUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/users")
public class UsersController {

  private static final Logger log = LoggerFactory.getLogger(UsersController.class);

  private final List<User> ALL_USERS = List.of(new User(1, "Batman", List.of(new Product(1, ""))), new User(2, "Robin"), new User(3, "Patrick"));
  private final ProductsClient productsClient;
  @Value("${service.envInfo}")
  private String envInfo;

  public UsersController(ProductsClient productsClient) {
    this.productsClient = productsClient;
  }

  @GetMapping
  public List<User> getAll() {
    log.info("GET /users -> resolving products for {} users", ALL_USERS.size());
    ALL_USERS.forEach(user -> {
      if (!CollectionUtils.isEmpty(user.getProducts())) {
        user.getProducts().forEach(product -> {
          log.debug("GET /users -> resolving product id={} for user id={}", product.getId(), user.getId());
          product.setName(productsClient.getById(product.getId()).getName());
        });
      }
    });
    return ALL_USERS;
  }

  @PostMapping("/{userId}/products/{productId}")
  public User addProduct(@PathVariable Integer userId, @PathVariable Integer productId) {
    log.info("POST /users/{}/products/{}", userId, productId);
    User user = ALL_USERS.stream().filter(u -> u.getId().equals(userId)).findFirst().orElseThrow(() -> new RuntimeException("User not found: " + userId));
    Product product = productsClient.getById(productId);
    log.debug("POST /users/{}/products/{} -> adding product: {}", userId, productId, product);
    List<Product> products = new ArrayList<>(user.getProducts() == null ? List.of() : user.getProducts());
    products.add(product);
    user.setProducts(products);
    return user;
  }

  @GetMapping("/env-info")
  public String getEnvInfo() {
    log.info("GET /users/env-info -> envInfo={}", envInfo);
    return envInfo;
  }

}
