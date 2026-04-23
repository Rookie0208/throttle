package com.ridersclub.ride.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

@Data
public class AddClubMembersRequest {

    @NotEmpty(message = "Select at least one user")
    private List<String> userUuids;
}
