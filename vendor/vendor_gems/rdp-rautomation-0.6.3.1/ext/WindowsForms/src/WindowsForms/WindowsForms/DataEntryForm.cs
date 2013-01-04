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
    public partial class DataEntryForm : Form
    {
        public DataEntryForm()
        {
            InitializeComponent();
        }

        private void closeDataEntryFormButton_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void addItemButton_Click(object sender, EventArgs e)
        {
            PersonForm personForm = new PersonForm(this);
            personForm.Show();
        }

        public void addPerson(String personName, String dateOfBirth)
        {
            ListViewItem newItem = new ListViewItem(personName);
            newItem.SubItems.Add(dateOfBirth);
            personListView.Items.Add(newItem);
        }

        private void deleteItemButton_Click(object sender, EventArgs e)
        {
            foreach (ListViewItem item in personListView.SelectedItems)
            {
                personListView.Items.Remove(item);
            }
        }

    }
}
