using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float speed = 5f, jumpPow = 10f;
    private Rigidbody rb;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        //charCon = GetComponent<CharacterController>();
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        float x = Input.GetAxis("Horizontal");
        float y = Input.GetAxis("Vertical");

        Vector3 moveChar = transform.right * x + transform.forward * y;

        rb.linearVelocity = moveChar * speed;
    }
}
