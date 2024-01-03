float calculateSphereRadius(float volume) {
  float radius = pow((3 * volume * PI) / 4, 1.0 / 3.0);
  return radius;
}

enum ParticleType {
  URANIUM,
    XENON,
    STRONTIUM,
    NEUTRON,
}

class Particle {
  PVector position;     // Position
  float r;              // Radius
  PVector velocity;     // Velocity
  color c;              // Particle color
  float m;
  ParticleType type;

  Particle(float x, float y, float r) {
    this.position = new PVector(x, y);
    this.velocity = new PVector(0, 0);
    this.r = r;
  }

  Particle(float r) {
    this.position = new PVector(random(0+r, width-r), random(0+r, height-r));
    this.velocity = new PVector(0, 0);
    this.r = r;
  }

  // Function to detect collision with another particle
  boolean colliding(Particle other) {
    float distance = position.dist(other.position);
    float minDistance = r + other.r;
    return (distance < minDistance);
  }

  // Function to draw the particle
  void display() {
    fill(c);
    ellipse(position.x, position.y, 2 * r, 2 * r);
  }

  // Function to update the particle's position
  void update() {
    position.add(velocity.x*speed, velocity.y*speed);
  }

  void checkBoundaryCollision() {
    if (this.position.x > width - this.r) {
      this.position.x = width - this.r;
      this.velocity.x *= -1;
    } else if (this.position.x < this.r) {
      this.position.x = this.r;
      this.velocity.x *= -1;
    } else if (this.position.y > height - this.r) {
      this.position.y = height - this.r;
      this.velocity.y *= -1;
    } else if (this.position.y < this.r) {
      this.position.y = this.r;
      this.velocity.y *= -1;
    }
  }

  void onCollision(Particle other) {
  }

  ArrayList<Point> query(QuadTree quadTree) {
    return quadTree.query(new Rectangle(position.x-r*2, position.y-r*2, r*4, r*4), null);
  }

  void handleCollision(Particle other) {
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, this.position);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = this.r + other.r;

    if (distanceVectMag < minDistance) {
      float distanceCorrection = (minDistance - distanceVectMag) / 2.0;
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
      other.position.add(correctionVector);
      this.position.sub(correctionVector);

      // get angle of distanceVect
      float theta = distanceVect.heading();
      // precalculate trig values
      float sine = sin(theta);
      float cosine = cos(theta);

      /* bTemp will hold rotated ball positions. You
       just need to worry about bTemp[1].position */
      PVector[] bTemp = { new PVector(), new PVector() };

      /* this ball's position is relative to the other
       so you can use the vector between them (bVect) as the
       reference point in the rotation expressions.
       bTemp[0].x and bTemp[0].y will initialize
       automatically to 0.0, which is what you want
       since b[1] will rotate around b[0] */
      bTemp[1].x = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp[1].y = cosine * distanceVect.y - sine * distanceVect.x;

      // rotate Temporary velocities
      PVector[] vTemp = { new PVector(), new PVector() };

      vTemp[0].x = cosine * this.velocity.x + sine * this.velocity.y;
      vTemp[0].y = cosine * this.velocity.y - sine * this.velocity.x;
      vTemp[1].x = cosine * other.velocity.x + sine * other.velocity.y;
      vTemp[1].y = cosine * other.velocity.y - sine * other.velocity.x;

      /* Now that velocities are rotated, you can use 1D
       conservation of momentum equations to calculate
       the final velocity along the x-axis. */
      PVector[] vFinal = { new PVector(), new PVector() };

      // final rotated velocity for b[0]
      vFinal[0].x = ((this.m - other.m) * vTemp[0].x + 2 * other.m * vTemp[1].x) / (this.m + other.m);
      vFinal[0].y = vTemp[0].y;

      // final rotated velocity for b[0]
      vFinal[1].x = ((other.m - this.m) * vTemp[1].x + 2 * this.m * vTemp[0].x) / (this.m + other.m);
      vFinal[1].y = vTemp[1].y;

      // hack to avoid clumping
      bTemp[0].x += vFinal[0].x;
      bTemp[1].x += vFinal[1].x;

      /* Rotate ball positions and velocities back
       Reverse signs in trig expressions to rotate
       in the opposite direction */
      // rotate balls
      PVector[] bFinal = { new PVector(), new PVector() };

      bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
      bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
      bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
      bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

      // update balls' positions
      other.position.x = this.position.x + bFinal[1].x;
      other.position.y = this.position.y + bFinal[1].y;

      this.position.add(bFinal[0]);

      // update velocities
      this.velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
      this.velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
      other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
      other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
    }
  }
}

class Uranium extends Particle {
  Uranium(float x, float y) {
    super(x, y, calculateSphereRadius(235));
    this.m = 235;
    this.c = color(0, 255, 0);
    this.type = ParticleType.URANIUM;
  }

  Uranium() {
    super(calculateSphereRadius(235));
    this.m = 235;
    this.c = color(0, 255, 0);
    this.type = ParticleType.URANIUM;
  }

  void onCollision(Particle other) {
    switch (other.type) {
    case URANIUM:
      handleCollision(other);
      break;
    case XENON:
      handleCollision(other);
      break;
    case STRONTIUM:
      handleCollision(other);
      break;
    case NEUTRON:
      Particle p = new Xenon(position.x, position.y);
      p.velocity = PVector.random2D().mult(.2);
      p.position.add(p.velocity.mult(10));
      particles.add(p);
      p = new Strontium(position.x, position.y);
      p.velocity = PVector.random2D().mult(.2);
      p.position.add(p.velocity.mult(10));
      particles.add(p);
      for (int i=0; i<3; i++) {
        p = new Neutron(position.x, position.y);
        p.velocity = PVector.random2D().mult(.2);
        p.position.add(p.velocity.mult(10));
        particles.add(p);
      }
      particles.remove(this);
      particles.remove(other);
      break;
    }
  }
}

class Xenon extends Particle {
  Xenon(float x, float y) {
    super(x, y, calculateSphereRadius(131));
    this.m = 131;
    this.c = color(0, 0, 255);
    this.type = ParticleType.XENON;
  }

  Xenon() {
    super(calculateSphereRadius(131));
    this.m = 131;
    this.c = color(0, 0, 255);
    this.type = ParticleType.XENON;
  }

  void onCollision(Particle other) {
    if (other.type != ParticleType.NEUTRON)
      handleCollision(other);
  }
}

class Strontium extends Particle {
  Strontium(float x, float y) {
    super(x, y, calculateSphereRadius(88));
    this.m = 88;
    this.c = color(255, 0, 0);
    this.type = ParticleType.STRONTIUM;
  }

  Strontium() {
    super(calculateSphereRadius(88));
    this.m = 88;
    this.c = color(255, 0, 0);
    this.type = ParticleType.STRONTIUM;
  }

  void onCollision(Particle other) {
    if (other.type != ParticleType.NEUTRON)
      handleCollision(other);
  }
}

class Neutron extends Particle {
  Neutron(float x, float y) {
    super(x, y, calculateSphereRadius(10));
    this.m = 1;
    this.c = color(255);
    this.type = ParticleType.NEUTRON;
  }

  Neutron() {
    super(calculateSphereRadius(10));
    this.m = 1;
    this.c = color(255, 0, 0);
    this.type = ParticleType.NEUTRON;
  }
}
