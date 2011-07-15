require 'java'

module M
   include_package 'javax.swing'
   include_package 'java.awt'
   JSlider
   BorderFactory
   BorderLayout
  
class JSliders < JFrame
  def initialize
    super "window title"
    slider = JSlider.new();
    slider.setBorder(BorderFactory.createTitledBorder("Multiply factor of half screen widths (higher is better, uses more cpu)"));
    
    slider.setMaximum(6);
    slider.setMajorTickSpacing(1); # boo :P

=begin
    
    #fail! what the...    slider.setMinorTickSpacing(0.5);
    
    labelTable = java.util.Hashtable.new
    labelTable.put(Integer.new(100),  JLabel.new("1.0"));  
    labelTable.put(new Integer(75), new JLabel("0.75"));  
    labelTable.put(new Integer(50), new JLabel("0.50"));  
    labelTable.put(new Integer(25), new JLabel("0.25"));  
    labelTable.put(new Integer(0), new JLabel("0.0"));  
    slider.setLabelTable( labelTable );  
=end    

    slider.setPaintTicks(true);
    slider.setPaintLabels(true);
    
    slider.snap_to_ticks=true
    
    slider.set_value 4
    
    
    slider.add_change_listener { |event|
     
    }

    
    
    content = getContentPane();
    content.add(slider, BorderLayout::SOUTH);
    pack();
    setVisible(true);
  end
end
  
    

end

M::JSliders.new