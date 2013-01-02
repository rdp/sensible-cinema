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
    public partial class PersonForm : Form
    {
        private DataEntryForm dataEntryForm;

        public PersonForm(DataEntryForm dataEntryForm)
        {
            InitializeComponent();
            this.dataEntryForm = dataEntryForm;
        }

        private void cancelButton_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void okButton_Click(object sender, EventArgs e)
        {
            dataEntryForm.addPerson(personName.Text, personDateOfBirth.Text);
            this.Close();
        }

    }
}
