using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace WindowsForms
{
    public partial class MainFormWindow : Form
    {
        public MainFormWindow()
        {
            InitializeComponent();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void aboutButton_Click(object sender, EventArgs e)
        {
            AboutBox aboutBox = new AboutBox();
            aboutBox.Show();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void checkBox_CheckedChanged(object sender, EventArgs e)
        {
            if (checkBox.Checked == true)
                checkBoxLabel.Text = "checkBox is on";
            else
                checkBoxLabel.Text = "checkBox is off";
        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            radioButtonLabel.Text = "Option 1 selected";
        }

        private void radioButton2_CheckedChanged(object sender, EventArgs e)
        {
            radioButtonLabel.Text = "Option 2 selected";
        }

        private void radioButtonReset_Click(object sender, EventArgs e)
        {
            radioButton1.Checked = false;
            radioButton2.Checked = false;
            radioButtonLabel.Text = "No option selected";
        }

        private void FruitsComboBox_SelectedIndexChanged(object sender, EventArgs e)
        {
            fruitsLabel.Text = FruitsComboBox.Text;
        }

        private void nextFormButton_Click(object sender, EventArgs e)
        {
            DataEntryForm form = new DataEntryForm();
            form.Show();
        }

        private void buttonButton_Click(object sender, EventArgs e)
        {
            SimpleElementsForm buttonForm = new SimpleElementsForm();
            buttonForm.Show();
        }

    }
}
