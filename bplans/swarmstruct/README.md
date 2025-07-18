# LA 2.0: LA2.gov
## AI-driven Urban Reconstruction

LA2.gov harnesses AI,
swarm robotics,
and innovative design principles like swarmism,
tectonism,
and parametric design to rebuild cities sustainably. Imagine cities dynamically redesigned and reconstructed to adapt to changing needs and trends.

Our mission begins with revitalizing Los Angeles and extends globally,
aiming to elevate third-world cities to first-world standards.

LA2.gov transforms cityscapes into evolving examples of human creativity and AI's capabilities. Join us in redefining urban life,
one city at a time.

## Overview

LA2.gov integrates key strategies:

- **Swarmism**: Utilizes swarm intelligence to address complex architectural problems, inspired by the collective behaviors of bees and ants.

- **Tectonism**: Focuses on construction both as a practical craft and an art form, creating structures that are both functional and aesthetically pleasing.

- **Parametric design**: Employs algorithms to shape building elements and components, driven by parameters that define the relationship between design objectives and outcomes.

## Structure

LA2.gov consists of two main technology components:

1. **[Ruby Component](https://ruby-lang.org/)**: A Roda-based application providing a user-friendly interface for managing the robotic swarm. It includes control and oversight of robots,
building processes,
and material repurposing.

2. **[Rust Component](https://rust-lang.org/)**: Manages the individual bots within the swarm with systems for bot actions,
coordination,
and handling of materials and structures.

### Current Developments
```txt
+-- ruby_component/
    +-- Gemfile
    +-- app/
        +-- controllers/
            +-- bots_controller.rb
            +-- destructions_controller.rb
            +-- materials_controller.rb
            +-- structures_controller.rb
            +-- swarms_controller.rb
        +-- models/
            +-- bot.rb
            +-- destruction.rb
            +-- material.rb
            +-- structure.rb
            +-- swarm.rb
        +-- routes/
            +-- bots.rb
            +-- swarms.rb
        +-- services/
            +-- bot_service.rb
            +-- swarm_service.rb
        +-- workers/
            +-- structure_assembly_worker.rb
            +-- structure_reshape_worker.rb
            +-- structure_teardown_worker.rb
    +-- config.ru
    +-- spec/
        +-- controllers/
            +-- bots_controller_spec.rb
            +-- swarms_controller_spec.rb
        +-- models/
            +-- bot_spec.rb
            +-- swarm_spec.rb
        +-- services/
            +-- bot_service_spec.rb
            +-- swarm_service_spec.rb
        +-- workers/
            +-- structure_assembly_worker_spec.rb
            +-- structure_reshape_worker_spec.rb
            +-- structure_teardown_worker_spec.rb
+-- rust_component/
    +-- Cargo.toml
    +-- src/
        +-- bot/
            +-- actions/
                +-- assemble_structure.rs
                +-- mod.rs
                +-- move.rs
                +-- reshape_material.rs
            +-- bot.rs
            +-- mod.rs
            +-- sensors/
                +-- mod.rs
                +-- sensors.rs
        +-- destruction/
            +-- destruction.rs
        +-- main.rs
        +-- material/
            +-- material.rs
            +-- mod.rs
        +-- structure/
            +-- structure.rs
        +-- swarm/
            +-- communication.rs
            +-- coordination.rs
            +-- mod.rs
            +-- swarm.rs
```