ArrayList<Particle> particles = new ArrayList<Particle>();

boolean showQuadTree = false;
boolean pause = false;

int capacity = 5;

int rows=10;
int cols=10;

float speed = .5;

float friction = .1;

Rectangle boundary;
QuadTree quadTree;

float lastMouseX;
float lastMouseY;

SliderWindow sliderWindow;

void setup() {
  size(640, 640);
  surface.setResizable(true);
  frameRate(100);
  sliderWindow = new SliderWindow(width - 350, 50, 300, color(50), "Config");
  sliderWindow.addSlider(new Slider(20, .01, 2, speed, color(0, 200, 20), "speed", 1));
  //sliderWindow.addSlider(new Slider(20, 1, 20, capacity, color(0, 200, 20), "capacity", 0));
  sliderWindow.addSlider(new Slider(20, 1, 100, rows, color(200, 0, 0), "rows", 0));
  sliderWindow.addSlider(new Slider(20, 1, 100, cols, color(0, 0, 200), "cols", 0));

  particles = new ArrayList<Particle>();

  for (int i = 0; i < cols; i++)
    for (int j = 0; j < rows; j++)
      particles.add(new Uranium(i * 30 + 100, j * 30 + 100));

  windowResized();
}

void updateParticles() {
  float startTime = millis();

  HashMap<Particle, Particle> queuedCollisions = new HashMap<Particle, Particle>();

  for (Particle p : particles) {
    p.display();
    p.update();
    p.checkBoundaryCollision();

    ArrayList<Point> queriedParticles = p.query(quadTree);

    for (Point other : queriedParticles) {
      if (particles.get(other.index)!=p && p.colliding(particles.get(other.index)))
        if (queuedCollisions.get(p)!=particles.get(other.index) && queuedCollisions.get(particles.get(other.index))!=p)
          queuedCollisions.put(p, particles.get(other.index));
    }
  }

  for (HashMap.Entry<Particle, Particle> entry : queuedCollisions.entrySet()) {

    entry.getKey().onCollision(entry.getValue());
  }
  float endTime = millis();
  println("Updating time: " + (endTime - startTime) + " ms");
}

void drawHUD() {
  fill(255);
  float size = 16;
  float paddingFactor = 1.5;
  textAlign(LEFT);
  textSize(size);

  text(frameRate, 10, size*paddingFactor*1);

  sliderWindow.display();
}

void draw() {
  background(0);

  //if (capacity != int(sliderWindow.getSliderValue(0))) {
  //  capacity = int(sliderWindow.getSliderValue(0));
  //}
  if (speed != sliderWindow.getSliderValue(0)) {
    speed = sliderWindow.getSliderValue(0);
  }
  if (!sliderWindow.isDragging) {
    if (rows != int(sliderWindow.getSliderValue(1))) {
      rows = int(sliderWindow.getSliderValue(1));
      setup();
    }
    if (cols != int(sliderWindow.getSliderValue(2))) {
      cols = int(sliderWindow.getSliderValue(2));
      setup();
    }
  }

  println();

  float startTime = millis();
  quadTree = new QuadTree(new Rectangle(width/2, height/2, width, height), capacity);

  int i=0;
  for (Particle p : particles) {
    quadTree.insert(new Point(p.position.x, p.position.y, i));
    i++;
  }

  float endTime = millis();
  println("QuadTree Generating time: " + (endTime - startTime) + " ms");

  updateParticles();

  startTime = millis();

  noStroke();

  if (showQuadTree)
    quadTree.draw(quadTree);

  drawHUD();

  if (mousePressed) {
    stroke(255, 255*.25);
    line(lastMouseX, lastMouseY, mouseX, mouseY);
  }


  endTime = millis();
  println("Drawing time: " + (endTime - startTime) + " ms");
}

void keyPressed() {
  if (key == 'r')
    setup();

  if (key == 'q')
    showQuadTree = !showQuadTree;

  if (key == 'p') {
    pause = !pause;
    if (pause) noLoop();
    else loop();
  }
}

void mousePressed() {
  sliderWindow.mousePressed();

  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void mouseReleased() {
  sliderWindow.mouseReleased();
  float dx = (mouseX - lastMouseX);
  float dy = (mouseY - lastMouseY);

  if (abs(dx)+abs(dy) >= 16) {
    Particle n = new Neutron(lastMouseX, lastMouseY);
    n.velocity = new PVector(dx*.01, dy*.01);
    particles.add(n);
  } else {
    particles.add(new Uranium(mouseX, mouseY));
  }
}
void mouseDragged() {
  sliderWindow.mouseDragged();
}

void windowResized() {
  sliderWindow.position(width - sliderWindow.w - 20, 20);
}
