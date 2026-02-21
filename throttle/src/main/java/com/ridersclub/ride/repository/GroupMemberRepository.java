package com.ridersclub.ride.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ridersclub.ride.entity.GroupMember;

public interface GroupMemberRepository extends JpaRepository<GroupMember, String> {

}
