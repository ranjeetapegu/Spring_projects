package com.ranjeeta.demo.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class Helloworld {
	

	@RequestMapping(method = RequestMethod.GET, value = "/hello/world")
	public String sayHello() {
		return "Swagger Hello World";
			
		}

	}

