package com.user;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

  private Integer id;
  private String name;
  private List<Product> products;

  public User(Integer id, String name) {
    this.id = id;
    this.name = name;
  }

}
