 require 'java'
 robot = java.awt.Robot.new
 img = robot.createScreenCapture(java.awt.Rectangle.new(java.awt.Toolkit.getDefaultToolkit().getScreenSize()));
javax.imageio.ImageIO.write(img, "BMP", java.io.File.new("filename.bmp"))


